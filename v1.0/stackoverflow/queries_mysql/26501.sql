
WITH TagsSplit AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        GROUP_CONCAT(DISTINCT ts.Tag ORDER BY ts.Tag SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        TagsSplit ts ON p.Id = ts.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.ViewCount, p.Score
), 
ScoreSummary AS (
    SELECT 
        pd.Author,
        SUM(pd.Score) AS TotalScore,
        AVG(pd.ViewCount) AS AverageViews,
        COUNT(pd.PostId) AS PostCount
    FROM 
        PostDetails pd
    GROUP BY 
        pd.Author
), 
HighScorers AS (
    SELECT 
        ss.Author,
        ss.TotalScore,
        ss.AverageViews,
        ss.PostCount,
        @rank := @rank + 1 AS Rank
    FROM 
        ScoreSummary ss, (SELECT @rank := 0) r
    WHERE 
        ss.TotalScore > 50 
    ORDER BY ss.TotalScore DESC
)

SELECT 
    hs.Rank, 
    hs.Author, 
    hs.TotalScore, 
    hs.AverageViews, 
    hs.PostCount,
    (SELECT COUNT(DISTINCT(ts.Tag)) 
     FROM TagsSplit ts 
     WHERE ts.PostId IN (SELECT pd.PostId FROM PostDetails pd WHERE pd.Author = hs.Author)) AS DistinctTagCount
FROM 
    HighScorers hs
ORDER BY 
    hs.Rank;
