WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS rank_per_year
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),

ActorRoles AS (
    SELECT 
        aka_name.person_id,
        aka_name.name,
        cast_info.movie_id,
        comp_cast_type.kind AS role_type,
        RANK() OVER (PARTITION BY aka_name.person_id ORDER BY cast_info.nr_order) AS role_rank
    FROM 
        aka_name
    JOIN 
        cast_info ON aka_name.person_id = cast_info.person_id
    LEFT JOIN 
        comp_cast_type ON cast_info.role_id = comp_cast_type.id
    WHERE 
        aka_name.name IS NOT NULL
),

FilteredActors AS (
    SELECT 
        person_id,
        name,
        COUNT(*) AS movie_count
    FROM 
        ActorRoles
    WHERE 
        role_rank <= 3
    GROUP BY 
        person_id, name
    HAVING 
        COUNT(*) > 1
),

MovieKeywords AS (
    SELECT 
        movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_id
),

FinalOutput AS (
    SELECT 
        RM.movie_id,
        RM.title,
        RM.production_year,
        FA.name AS actor_name,
        FA.movie_count,
        MK.keywords_list
    FROM 
        RankedMovies RM
    JOIN 
        FilteredActors FA ON RM.movie_id = FA.movie_id
    LEFT JOIN 
        MovieKeywords MK ON RM.movie_id = MK.movie_id
)

SELECT 
    *,
    CASE 
        WHEN production_year < 2000 THEN 'Classic'
        WHEN production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_period,
    COALESCE(keywords_list, 'No Keywords') AS final_keywords
FROM 
    FinalOutput
WHERE 
    actor_name IS NOT NULL
ORDER BY 
    production_year DESC, title ASC;
