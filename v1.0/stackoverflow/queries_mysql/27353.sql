
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        RANK() OVER (ORDER BY COUNT(DISTINCT v.Id) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
HighRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        Author,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        VoteRank <= 10
),
TagCounts AS (
    SELECT 
        TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        HighRankedPosts
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    GROUP BY 
        TagName
)
SELECT
    tc.TagName,
    tc.PostCount,
    COUNT(DISTINCT hrp.PostId) AS HighRankedPostCount,
    AVG(hrp.CommentCount) AS AvgComments,
    SUM(hrp.VoteCount) AS TotalVotes
FROM 
    TagCounts tc
JOIN 
    HighRankedPosts hrp ON hrp.Tags LIKE CONCAT('%', tc.TagName, '%')
GROUP BY 
    tc.TagName, tc.PostCount
ORDER BY 
    TotalVotes DESC, HighRankedPostCount DESC;
