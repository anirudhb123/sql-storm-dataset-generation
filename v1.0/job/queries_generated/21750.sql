WITH RecursiveActors AS (
    SELECT 
        ca.person_id,
        COUNT(*) AS film_count
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY 
        ca.person_id
    HAVING 
        COUNT(*) > 5
),
TitleCompanyCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mc.company_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY cn.name) as rn
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        mt.production_year > 2000
),
FilteredMovies AS (
    SELECT 
        title_id, 
        title, 
        COUNT(DISTINCT company_id) AS company_count,
        MAX(company_name) AS leading_company,
        MIN(CASE WHEN rn = 1 THEN company_name END) AS first_company_name
    FROM 
        TitleCompanyCTE
    GROUP BY 
        title_id, title
    HAVING 
        COUNT(DISTINCT company_id) > 1
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        mi.info AS info_text,
        it.info AS info_type_text
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        mi.info LIKE '%Award%' OR mi.info LIKE '%Nominee%'
),
FinalResults AS (
    SELECT 
        f.title AS movie_title,
        f.company_count,
        f.leading_company,
        COALESCE(mi.info_text, 'No Info') AS award_info,
        COALESCE(ra.film_count, 0) AS actor_film_count
    FROM 
        FilteredMovies f
    LEFT JOIN 
        MovieInfo mi ON f.title_id = mi.movie_id
    LEFT JOIN 
        RecursiveActors ra ON ra.person_id IN (
            SELECT DISTINCT person_id 
            FROM cast_info ci 
            WHERE ci.movie_id = f.title_id
        )
)
SELECT 
    fr.movie_title,
    fr.company_count,
    fr.leading_company,
    fr.award_info,
    fr.actor_film_count
FROM 
    FinalResults fr
WHERE 
    fr.actor_film_count >= 3
ORDER BY 
    fr.company_count DESC, 
    fr.movie_title ASC;
