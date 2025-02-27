WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM title t
    JOIN aka_title at ON t.id = at.movie_id
    WHERE at.production_year IS NOT NULL
),
ActorStats AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
MovieDetails AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        as.actor_count,
        as.actor_names
    FROM RankedMovies rm
    JOIN ActorStats as ON rm.movie_id = as.movie_id
    WHERE rm.rank <= 5
),
KeywordStats AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_count,
    md.actor_names,
    ks.keywords
FROM MovieDetails md
LEFT JOIN KeywordStats ks ON md.movie_id = ks.movie_id
ORDER BY md.production_year DESC, md.actor_count DESC;
