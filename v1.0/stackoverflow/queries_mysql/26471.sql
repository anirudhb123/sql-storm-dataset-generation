
WITH RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        COALESCE(COUNT(c.Id) OVER (PARTITION BY p.Id), 0) AS CommentCount,
        p.Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY)
),
TagMetrics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CommentCount) AS TotalComments,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        RecentActivity
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagMetrics
)
SELECT 
    Rank,
    Tag,
    PostCount,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes
FROM 
    TopTags
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
