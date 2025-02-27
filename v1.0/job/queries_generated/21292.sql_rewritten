WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        ac.actor_count,
        COALESCE(MAX(mi.info), 'No info available') AS movie_info
    FROM 
        aka_title m
    LEFT JOIN 
        ActorCounts ac ON m.id = ac.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id, m.title, ac.actor_count
),
MoviesWithGenres AS (
    SELECT 
        md.movie_id,
        md.title,
        md.actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_keyword mk ON md.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        md.movie_id, md.title, md.actor_count
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    GROUP BY 
        m.movie_id
),
FinalResults AS (
    SELECT 
        mw.movie_id,
        mw.title,
        mw.actor_count,
        mw.genres,
        ci.companies,
        ROW_NUMBER() OVER (ORDER BY mw.actor_count DESC, mw.title ASC) AS popularity_rank
    FROM 
        MoviesWithGenres mw
    LEFT JOIN 
        CompanyInfo ci ON mw.movie_id = ci.movie_id
    WHERE 
        mw.actor_count IS NOT NULL
)

SELECT 
    fr.movie_id,
    fr.title,
    fr.actor_count,
    fr.genres,
    COALESCE(fr.companies, '{}') AS companies,
    fr.popularity_rank
FROM 
    FinalResults fr
WHERE 
    fr.popularity_rank <= 10
ORDER BY 
    fr.popularity_rank;