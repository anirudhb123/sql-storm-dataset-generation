WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(MAX(k.keyword), 'No Keywords') AS keywords,
        COUNT(DISTINCT cm.company_id) AS company_count
    FROM
        RankedMovies rm
    LEFT JOIN
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies cm ON rm.movie_id = cm.movie_id
    WHERE 
        rm.rank_per_year <= 3 
    GROUP BY
        rm.movie_id, rm.title, rm.production_year
),
TopMovieActors AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    WHERE
        ci.person_role_id IN (SELECT id FROM role_type WHERE role ILIKE '%actor%')
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.company_count,
    STRING_AGG(tma.actor_name, ', ' ORDER BY tma.actor_rank) AS top_actors
FROM
    MovieDetails md
LEFT JOIN
    TopMovieActors tma ON md.movie_id = tma.movie_id
GROUP BY
    md.movie_id, md.title, md.production_year, md.keywords, md.company_count
ORDER BY
    md.production_year DESC,
    md.company_count DESC,
    md.title;