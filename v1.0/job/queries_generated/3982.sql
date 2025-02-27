WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title) AS rank
    FROM aka_title at
    WHERE at.production_year IS NOT NULL
),
TopTitles AS (
    SELECT 
        rt.title,
        rt.production_year
    FROM RankedTitles rt
    WHERE rt.rank <= 5
),
PersonRoles AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY ci.person_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keyword, 'No Keywords') AS keywords,
        AVG(CASE WHEN mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating') THEN CAST(mi.info AS FLOAT) END) AS avg_rating
    FROM title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    GROUP BY m.id, m.title
)
SELECT 
    p.name,
    tr.production_year,
    tr.title,
    pd.keywords,
    pd.avg_rating,
    pr.movie_count,
    pr.roles
FROM PersonRoles pr
JOIN aka_name p ON p.person_id = pr.person_id
JOIN TopTitles tr ON tr.production_year = (SELECT MAX(production_year) FROM TopTitles)
JOIN MovieDetails pd ON pd.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = p.person_id)
WHERE pr.movie_count > 1
ORDER BY pr.movie_count DESC, tr.production_year DESC;
