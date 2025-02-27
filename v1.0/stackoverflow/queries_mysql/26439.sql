
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS Author,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        AVG(v.BountyAmount) AS AvgBounty,
        RANK() OVER (ORDER BY COUNT(DISTINCT a.Id) DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 8 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.LastActivityDate, u.DisplayName
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.Author,
        rp.AnswerCount,
        rp.AvgBounty,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS AssociatedTags
    FROM 
        RankedPosts rp
    JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, ',', n.n), ',', -1) AS TagName
         FROM (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
               SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
         WHERE n.n <= 1 + LENGTH(rp.Tags) - LENGTH(REPLACE(rp.Tags, ',', ''))) t ON TRUE
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.Tags, rp.CreationDate, rp.LastActivityDate, rp.Author, rp.AnswerCount, rp.AvgBounty
),
PostStats AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Author,
        p.AnswerCount,
        p.AvgBounty,
        p.AssociatedTags,
        TIMESTAMPDIFF(SECOND, p.LastActivityDate, '2024-10-01 12:34:56') AS DaysSinceLastActivity
    FROM 
        TaggedPosts p
)
SELECT 
    ps.Title,
    ps.Author,
    ps.AnswerCount,
    ps.AvgBounty,
    ps.AssociatedTags,
    ps.DaysSinceLastActivity
FROM 
    PostStats ps
WHERE 
    ps.DaysSinceLastActivity < 604800 
ORDER BY 
    ps.AnswerCount DESC, ps.AvgBounty DESC
LIMIT 10;
