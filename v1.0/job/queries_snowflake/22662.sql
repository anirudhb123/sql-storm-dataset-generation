
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(cast_info.id) DESC) AS rank
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
),
DistinctAkaNames AS (
    SELECT 
        person_id, 
        COUNT(DISTINCT name) AS unique_names
    FROM 
        aka_name
    GROUP BY 
        person_id
    HAVING 
        COUNT(DISTINCT name) > 1
),
MovieKeywords AS (
    SELECT 
        movie_id, 
        LISTAGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_id
),
PersonRoles AS (
    SELECT 
        ci.movie_id, 
        ci.person_id, 
        LISTAGG(rt.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, ci.person_id
),
InterestingMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        DENSE_RANK() OVER (ORDER BY rm.rank) AS interesting_rank,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(da.unique_names, 0) AS actor_variety
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        DistinctAkaNames da ON rm.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = da.person_id)
    WHERE 
        rm.rank <= 5 
)
SELECT 
    im.title,
    im.production_year,
    im.keywords,
    im.interesting_rank,
    im.actor_variety,
    'Cast Info: ' || COALESCE(LISTAGG(COALESCE(pr.roles, 'Unknown role'), '; '), 'No cast') AS cast_roles 
FROM 
    InterestingMovies im
LEFT JOIN 
    PersonRoles pr ON im.movie_id = pr.movie_id
GROUP BY 
    im.title, im.production_year, im.keywords, im.interesting_rank, im.actor_variety
ORDER BY 
    im.production_year DESC, im.interesting_rank;
