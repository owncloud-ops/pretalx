from django.contrib.auth.management.commands import createsuperuser
from django.core.management import CommandError


class Command(createsuperuser.Command):
    help = "Create default pretalx admin user"

    def add_arguments(self, parser):
        super(Command, self).add_arguments(parser)
        parser.add_argument(
            "--username",
            dest="username",
            default=None,
            help="Specifies the display name for the admin user.",
        )
        parser.add_argument(
            "--password",
            dest="password",
            default=None,
            help="Specifies the password for the admin user.",
        )
        parser.add_argument(
            "--preserve",
            dest="preserve",
            default=False,
            action="store_true",
            help="Exit normally if the user already exists.",
        )

    def handle(self, *args, **options):
        password = options.get("password")
        username = options.get("username")
        email = options.get("email")
        database = options.get("database")

        if password and not email:
            raise CommandError("--email is required if specifying --password")

        if password and not username:
            raise CommandError(
                "--username is required if specifying --password")

        if email and options.get("preserve"):
            exists = (
                self.UserModel._default_manager.db_manager(database).filter(
                    email=email).exists())
            if exists:
                self.stdout.write(
                    "User exists, exiting normally due to --preserve")
                return

        options["interactive"] = False
        super(Command, self).handle(*args, **options)

        if password:
            user = self.UserModel._default_manager.db_manager(database).get(
                email=email)
            user.set_password(password)
            user.save()

        if username:
            user = self.UserModel._default_manager.db_manager(database).get(
                email=email)
            user.name = username
            user.save()
