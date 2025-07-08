
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.role_id) AS unique_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
MovieInfoDetails AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'rating' THEN mi.info END) AS max_rating,
        MIN(CASE WHEN it.info = 'rating' THEN mi.info END) AS min_rating,
        COUNT(mi.id) AS info_count
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mt.title AS movie_title,
    mt.production_year,
    csv.unique_roles AS actor_roles,
    RANK() OVER (ORDER BY mc.total_companies DESC) AS company_rank,
    mim.max_rating,
    mim.min_rating,
    RANK() OVER (ORDER BY mim.max_rating DESC) AS rating_rank
FROM 
    RankedTitles mt
LEFT JOIN 
    MovieCompanies mc ON mt.title_id = mc.movie_id
LEFT JOIN 
    ActorRoleCounts csv ON csv.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = mt.title_id)
LEFT JOIN 
    MovieInfoDetails mim ON mim.movie_id = mt.title_id
WHERE 
    mt.title_rank <= 5  
    AND (mim.max_rating IS NOT NULL OR mim.min_rating IS NOT NULL)  
ORDER BY 
    mt.production_year DESC, 
    company_rank ASC, 
    rating_rank ASC;
