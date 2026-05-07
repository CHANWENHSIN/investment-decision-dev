import os

from supabase import Client, create_client


def get_supabase_client() -> Client:
    """Create and return a Supabase client from environment variables."""
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_KEY")

    missing_vars = [
        var_name
        for var_name, value in {
            "SUPABASE_URL": supabase_url,
            "SUPABASE_KEY": supabase_key,
        }.items()
        if not value
    ]

    if missing_vars:
        missing = ", ".join(missing_vars)
        raise ValueError(
            f"Missing required environment variable(s): {missing}. "
            "Please set them before creating the Supabase client."
        )

    return create_client(supabase_url, supabase_key)
