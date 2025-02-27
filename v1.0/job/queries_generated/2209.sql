WITH MovieDetails AS (
    SELECT 
        at.title, 
        at.production_year, 
        COUNT(DISTINCT cc.person_id) AS total_cast,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS has_role_cast,
        AVG(CASE WHEN m1.info IS NOT NULL THEN CAST(m1.info AS numeric) ELSE NULL END) AS avg_rating
    FROM aka_title at
    LEFT JOIN complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN movie_info m1 ON at.id = m1.movie_id AND m1.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY at.title, at.production_year
),
KeywordSummary AS (
    SELECT 
        at.title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM aka_title at
    LEFT JOIN movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY at.title
),
RoleOverview AS (
    SELECT 
        at.title,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles,
        COUNT(*) AS role_count
    FROM cast_info ci
    JOIN role_type rt ON ci.person_role_id = rt.id
    JOIN aka_title at ON ci.movie_id = at.id
    GROUP BY at.title
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.has_role_cast,
    md.avg_rating,
    ks.keywords,
    ks.keyword_count,
    ro.roles,
    ro.role_count
FROM MovieDetails md
JOIN KeywordSummary ks ON md.title = ks.title
JOIN RoleOverview ro ON md.title = ro.title
WHERE md.production_year >= 2000 
  AND md.total_cast > 5 
  AND (md.avg_rating IS NULL OR md.avg_rating > 7.0)
ORDER BY md.production_year DESC, md.total_cast DESC;
