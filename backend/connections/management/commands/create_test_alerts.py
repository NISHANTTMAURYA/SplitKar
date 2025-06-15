from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from connections.models import FriendRequest, Group, GroupInvitation
import random
import string

class Command(BaseCommand):
    help = 'Creates multiple test friend requests and group invitations for a specified user.'

    def add_arguments(self, parser):
        parser.add_argument('username', type=str, help='The username of the target user to create alerts for.')
        parser.add_argument(
            '--num_friends',
            type=int,
            default=5,
            help='Number of friend requests to create (default: 5)'
        )
        parser.add_argument(
            '--num_groups',
            type=int,
            default=5,
            help='Number of group invitations to create (default: 5)'
        )

    def handle(self, *args, **kwargs):
        username = kwargs['username']
        num_friends = kwargs['num_friends']
        num_groups = kwargs['num_groups']

        try:
            target_user = User.objects.get(username=username)
        except User.DoesNotExist:
            raise CommandError(f'User "{username}" does not exist.')

        self.stdout.write(self.style.NOTICE(f'Creating test alerts for user: {target_user.username}'))

        # --- Create Friend Requests ---
        self.stdout.write(self.style.HTTP_INFO(f'Attempting to create {num_friends} friend requests...'))
        other_users = list(User.objects.exclude(id=target_user.id).order_by('?')[:num_friends * 2]) # Get more than needed
        
        friend_requests_created = 0
        for i in range(num_friends):
            if not other_users:
                self.stdout.write(self.style.WARNING("Not enough other users to create more friend requests."))
                break
            
            from_user = random.choice(other_users)
            other_users.remove(from_user) # Ensure unique sender for each request
            
            try:
                FriendRequest.objects.send_request(from_user=from_user, to_user=target_user)
                self.stdout.write(self.style.SUCCESS(f'Successfully sent friend request from {from_user.username}'))
                friend_requests_created += 1
            except ValidationError as e:
                self.stdout.write(self.style.WARNING(f'Skipped friend request from {from_user.username}: {e}'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'Error creating friend request from {from_user.username}: {e}'))
        
        self.stdout.write(self.style.SUCCESS(f'Created {friend_requests_created} friend requests.'))

        # --- Create Group Invitations ---
        self.stdout.write(self.style.HTTP_INFO(f'Attempting to create {num_groups} group invitations...'))
        
        # Get a list of potential group creators (any user except the target user)
        potential_group_creators = list(User.objects.exclude(id=target_user.id))

        if not potential_group_creators:
            self.stdout.write(self.style.ERROR("No other users available to create groups for invitations."))
            return
        
        group_invitations_created = 0
        for i in range(num_groups):
            # Create a new group for each invitation
            group_creator = random.choice(potential_group_creators)
            group_name = f"Test Group {i + 1} - {''.join(random.choices(string.ascii_uppercase + string.digits, k=5))}"
            group_description = f"Description for {group_name}"
            
            try:
                new_group = Group.objects.create(
                    name=group_name,
                    description=group_description,
                    created_by=group_creator,
                    group_type='regular'
                )
                new_group.members.add(group_creator) # Creator is automatically a member
                self.stdout.write(self.style.SUCCESS(f'Created new group: {new_group.name} by {group_creator.username}'))

                # Send invitation from the group creator to the target user
                GroupInvitation.objects.create(
                    group=new_group,
                    invited_user=target_user,
                    invited_by=group_creator,
                    status='pending'
                )
                self.stdout.write(self.style.SUCCESS(f'Successfully sent group invitation for new group {new_group.name} to {target_user.username} from {group_creator.username}'))
                group_invitations_created += 1

            except ValidationError as e:
                self.stdout.write(self.style.WARNING(f'Skipped group creation/invitation for {group_name}: {e}'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'Error creating group or invitation for {group_name}: {e}'))
        
        self.stdout.write(self.style.SUCCESS(f'Created {group_invitations_created} group invitations.'))

        self.stdout.write(self.style.SUCCESS('All test alerts creation process completed.')) 