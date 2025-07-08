
WITH RankedMovies AS (
    SELECT
        T.id AS movie_id,
        T.title,
        T.production_year,
        ROW_NUMBER() OVER (PARTITION BY T.production_year ORDER BY T.title) AS rank_by_year
    FROM
        aka_title T
    WHERE
        T.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT
        C.id AS company_id,
        C.name,
        CT.kind AS company_type
    FROM
        company_name C
    JOIN
        company_type CT ON C.id = CT.id
),
CastDetails AS (
    SELECT
        CI.id AS cast_id,
        A.name AS actor_name,
        T.title AS movie_title,
        T.production_year,
        CASE 
            WHEN CI.note IS NULL THEN 'No additional notes'
            ELSE CI.note
        END AS role_note
    FROM
        cast_info CI
    JOIN
        aka_name A ON CI.person_id = A.person_id
    JOIN
        aka_title T ON CI.movie_id = T.movie_id
),
MovieKeywords AS (
    SELECT
        MK.movie_id,
        LISTAGG(K.keyword, ', ') WITHIN GROUP (ORDER BY K.keyword) AS keywords
    FROM 
        movie_keyword MK
    JOIN 
        keyword K ON MK.keyword_id = K.id
    GROUP BY 
        MK.movie_id
)
SELECT
    RM.rank_by_year,
    RM.title AS movie_title,
    RM.production_year,
    CD.name AS company_name,
    CD.company_type,
    COALESCE(CD.company_type, 'Independent') AS company_type_fallback,
    CD.company_id,
    CD.company_id IS NULL AS is_company_null,
    CD.company_id IN (SELECT company_id FROM movie_companies WHERE movie_id = RM.movie_id) AS is_linked,
    CD.company_id NOT IN (SELECT company_id FROM movie_companies) AS company_unlinked,
    (SELECT COUNT(*) 
     FROM person_info
     WHERE person_id IN (SELECT person_id FROM cast_info WHERE movie_id = RM.movie_id) 
       AND info_type_id = 1) AS num_awards
FROM 
    RankedMovies RM
LEFT JOIN 
    MovieKeywords MK ON RM.movie_id = MK.movie_id
LEFT JOIN 
    movie_companies MC ON RM.movie_id = MC.movie_id
LEFT JOIN 
    CompanyDetails CD ON MC.company_id = CD.company_id
WHERE 
    RM.production_year > 2000 
    AND RM.rank_by_year <= 5 
    AND (MK.keywords LIKE '%Action%' OR RM.title LIKE '%Adventure%')
GROUP BY 
    RM.rank_by_year,
    RM.title,
    RM.production_year,
    CD.name,
    CD.company_type,
    CD.company_id
ORDER BY 
    RM.production_year DESC, 
    RM.title ASC;
