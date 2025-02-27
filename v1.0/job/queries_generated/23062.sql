WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT cc.person_id) AS total_cast,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),

PersonDetails AS (
    SELECT 
        ak.person_id,
        ak.name,
        ak.surname_pcode,
        pi.info,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY pi.info_type_id) AS rn
    FROM 
        aka_name ak
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id
    WHERE 
        ak.name IS NOT NULL
),

FinalSelection AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.keyword,
        pd.name,
        pd.surname_pcode,
        md.total_cast,
        md.total_companies,
        pd.info AS person_info,
        CASE 
            WHEN md.total_cast = 0 THEN 'No Cast'
            WHEN md.total_companies = 0 THEN 'No Companies'
            ELSE 'Available'
        END AS availability_status
    FROM 
        MovieDetails md
    LEFT JOIN 
        PersonDetails pd ON md.total_cast > 0 AND pd.rn = 1
    WHERE 
        (pd.name IS NULL OR pd.surname_pcode IS NOT NULL) 
        AND (md.keyword IS NOT NULL OR md.production_year IS NOT NULL)
)

SELECT 
    DISTINCT fs.title_id,
    fs.title,
    fs.production_year,
    fs.keyword,
    COALESCE(fs.name, 'Unknown') AS actor_name,
    fs.surname_pcode,
    fs.total_cast,
    fs.total_companies,
    fs.person_info,
    fs.availability_status
FROM 
    FinalSelection fs
ORDER BY 
    fs.production_year DESC,
    fs.title ASC;

