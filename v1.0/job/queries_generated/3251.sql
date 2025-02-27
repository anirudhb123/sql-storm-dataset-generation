WITH MovieAwards AS (
    SELECT
        a.title AS MovieTitle,
        COUNT(DISTINCT mw.id) AS AwardCount,
        AVG(CASE WHEN mw.year >= 2000 THEN mw.year END) AS RecentAwards,
        STRING_AGG(DISTINCT c.name, ', ') AS Companies
    FROM
        aka_title a
    LEFT JOIN
        movie_info m ON a.id = m.movie_id
    LEFT JOIN
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    LEFT JOIN
        movie_info_idx mw ON a.id = mw.movie_id AND mw.info_type_id = (SELECT id FROM info_type WHERE info = 'Award')
    GROUP BY
        a.title
),
RankedMovies AS (
    SELECT
        MovieTitle,
        AwardCount,
        RecentAwards,
        Companies,
        ROW_NUMBER() OVER (ORDER BY AwardCount DESC, RecentAwards DESC) AS Rank
    FROM
        MovieAwards
)
SELECT
    RM.MovieTitle,
    RM.AwardCount,
    COALESCE(RM.RecentAwards, 'No Awards') AS RecentAwards,
    RM.Companies,
    COUNT(DISTINCT ci.person_id) AS CastCount,
    STRING_AGG(DISTINCT CONCAT(n.name, ' (', rt.role, ')'), ', ') AS CastDetails
FROM
    RankedMovies RM
LEFT JOIN
    cast_info ci ON RM.MovieTitle = (SELECT a.title FROM aka_title a WHERE a.id = ci.movie_id)
LEFT JOIN
    role_type rt ON ci.role_id = rt.id
LEFT JOIN
    aka_name n ON ci.person_id = n.person_id
WHERE
    RM.Rank <= 10
GROUP BY
    RM.MovieTitle, RM.AwardCount, RM.RecentAwards, RM.Companies
ORDER BY
    RM.AwardCount DESC;
