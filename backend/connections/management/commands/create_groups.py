import random
from datetime import date, timedelta
from decimal import Decimal
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from connections.models import Group, Profile


class Command(BaseCommand):
    help = 'Populate the database with groups using random users'

    def add_arguments(self, parser):
        parser.add_argument(
            '--num-groups',
            type=int,
            default=10,
            help='Number of groups to create (default: 10)'
        )
        parser.add_argument(
            '--min-members',
            type=int,
            default=2,
            help='Minimum number of members per group (default: 2)'
        )
        parser.add_argument(
            '--max-members',
            type=int,
            default=8,
            help='Maximum number of members per group (default: 8)'
        )
        parser.add_argument(
            '--trip-ratio',
            type=float,
            default=0.3,
            help='Ratio of trip groups to regular groups (default: 0.3)'
        )

    def handle(self, *args, **options):
        num_groups = options['num_groups']
        min_members = options['min_members']
        max_members = options['max_members']
        trip_ratio = options['trip_ratio']

        # Get all available users
        users = list(User.objects.all())
        
        if len(users) < 2:
            self.stdout.write(
                self.style.ERROR('Need at least 2 users in the database to create groups')
            )
            return

        self.stdout.write(f'Found {len(users)} users in the database')
        self.stdout.write(f'Creating {num_groups} groups...')

        # Group names for regular groups
        regular_group_names = [
            "Weekend Warriors", "Coffee Club", "Book Lovers", "Movie Night", 
            "Gaming Squad", "Fitness Friends", "Foodies United", "Travel Buddies",
            "Study Group", "Workout Partners", "Dinner Club", "Adventure Seekers",
            "Tech Enthusiasts", "Music Lovers", "Art & Craft", "Photography Club",
            "Language Exchange", "Chess Club", "Running Group", "Cooking Class"
        ]

        # Trip destinations
        trip_destinations = [
            "Paris, France", "Tokyo, Japan", "New York, USA", "London, UK",
            "Sydney, Australia", "Rome, Italy", "Barcelona, Spain", "Amsterdam, Netherlands",
            "Bangkok, Thailand", "Dubai, UAE", "Singapore", "Vancouver, Canada",
            "Berlin, Germany", "Prague, Czech Republic", "Vienna, Austria",
            "Stockholm, Sweden", "Copenhagen, Denmark", "Oslo, Norway", "Helsinki, Finland",
            "Zurich, Switzerland"
        ]

        # Trip descriptions
        trip_descriptions = [
            "Exploring the city of lights and culture",
            "Immersing in Japanese traditions and modern life",
            "Experiencing the Big Apple's energy",
            "Discovering British history and charm",
            "Enjoying the beautiful beaches and wildlife",
            "Walking through ancient ruins and art",
            "Savoring tapas and Mediterranean vibes",
            "Cycling through picturesque canals",
            "Tasting street food and visiting temples",
            "Luxury shopping and desert adventures",
            "Modern city with diverse cultures",
            "Nature and urban life combined",
            "Historical sites and vibrant nightlife",
            "Medieval architecture and beer culture",
            "Classical music and imperial palaces",
            "Scandinavian design and nature",
            "Hygge lifestyle and cycling culture",
            "Fjords and northern lights",
            "Design and technology hub",
            "Alpine adventures and chocolate"
        ]

        groups_created = 0
        trip_groups_created = 0
        regular_groups_created = 0

        for i in range(num_groups):
            # Determine if this should be a trip group
            is_trip_group = random.random() < trip_ratio
            
            # Select a random creator
            creator = random.choice(users)
            
            if is_trip_group:
                # Create trip group
                destination_idx = random.randint(0, len(trip_destinations) - 1)
                destination = trip_destinations[destination_idx]
                description = trip_descriptions[destination_idx]
                
                # Generate random dates (within next 2 years)
                start_date = date.today() + timedelta(days=random.randint(30, 730))
                end_date = start_date + timedelta(days=random.randint(3, 21))
                
                # Random trip status (mostly planned, some ongoing)
                trip_status = random.choices(
                    ['planned', 'ongoing', 'completed', 'cancelled'],
                    weights=[0.7, 0.2, 0.08, 0.02]
                )[0]
                
                # Random budget
                budget = Decimal(random.randint(500, 10000))
                
                group = Group.objects.create(
                    name=f"Trip to {destination}",
                    description=description,
                    created_by=creator,
                    group_type='trip',
                    destination=destination,
                    start_date=start_date,
                    end_date=end_date,
                    trip_status=trip_status,
                    budget=budget
                )
                trip_groups_created += 1
            else:
                # Create regular group
                name = random.choice(regular_group_names)
                description = f"A group for {name.lower()} to connect and share experiences."
                
                group = Group.objects.create(
                    name=name,
                    description=description,
                    created_by=creator,
                    group_type='regular'
                )
                regular_groups_created += 1

            # Add members to the group
            num_members = random.randint(min_members, min(max_members, len(users)))
            
            # Always add the creator
            group.members.add(creator)
            
            # Add random members (excluding creator)
            available_users = [u for u in users if u != creator]
            selected_members = random.sample(available_users, min(num_members - 1, len(available_users)))
            
            for member in selected_members:
                group.members.add(member)

            groups_created += 1
            
            self.stdout.write(
                self.style.SUCCESS(
                    f'Created group "{group.name}" with {group.member_count} members '
                    f'(Type: {group.group_type})'
                )
            )

        self.stdout.write(
            self.style.SUCCESS(
                f'\nSuccessfully created {groups_created} groups:\n'
                f'- {regular_groups_created} regular groups\n'
                f'- {trip_groups_created} trip groups'
            )
        ) 