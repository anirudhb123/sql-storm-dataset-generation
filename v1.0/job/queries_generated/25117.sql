WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PrintedNames AS (
    SELECT
        ak.name AS aka_name,
        n.name AS real_name,
        COUNT(c.movie_id) AS total_movies
    FROM 
        aka_name ak
    JOIN 
        name n ON ak.person_id = n.imdb_id
    LEFT JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.name, n.name
    HAVING 
        COUNT(c.movie_id) > 5
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
AdvancedInfo AS (
    SELECT
        r.title_id,
        r.title,
        r.production_year,
        pn.aka_name,
        pn.real_name,
        cd.company_name,
        cd.company_type,
        r.keyword_count
    FROM
        RankedTitles r
    JOIN
        PrintedNames pn ON r.title_id IN (SELECT movie_id FROM cast_info WHERE person_id IN (SELECT person_id FROM aka_name))
    LEFT JOIN 
        CompanyDetails cd ON r.title_id = cd.movie_id
)
SELECT 
    a.title,
    a.production_year,
    a.aka_name,
    a.real_name,
    a.company_name,
    a.company_type,
    a.keyword_count
FROM 
    AdvancedInfo a
WHERE 
    a.keyword_count > 3
ORDER BY 
    a.production_year DESC, 
    a.title ASC;
