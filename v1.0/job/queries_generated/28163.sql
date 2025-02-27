WITH MovieTitleKeyword AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        k.keyword AS movie_keyword
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year >= 2000
),
CastInfo AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(*) AS total_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
),
MovieDetails AS (
    SELECT 
        mt.movie_id,
        MAX(mt.movie_title) AS max_title,
        GROUP_CONCAT(DISTINCT mk.movie_keyword) AS keywords
    FROM 
        MovieTitleKeyword mt
    LEFT JOIN 
        CastInfo ci ON mt.movie_id = ci.movie_id
    GROUP BY 
        mt.movie_id
),
FinalOutput AS (
    SELECT 
        md.movie_id,
        md.max_title,
        md.keywords,
        COALESCE(ci.actor_name, 'No Cast') AS leading_actor,
        ci.total_roles AS roles_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        CastInfo ci ON md.movie_id = ci.movie_id
)
SELECT 
    fo.movie_id,
    fo.max_title,
    fo.keywords,
    fo.leading_actor,
    fo.roles_count
FROM 
    FinalOutput fo
ORDER BY 
    fo.roles_count DESC, 
    fo.keywords;

This SQL query is structured to benchmark string processing by aggregating movie titles with their associated keywords and cast information over a specified time period (from the year 2000 onward). The query uses Common Table Expressions (CTEs) to break down the logic into manageable components, which include retrieving movie titles and keywords, summarizing cast information, and then consolidating results into a final output format.
