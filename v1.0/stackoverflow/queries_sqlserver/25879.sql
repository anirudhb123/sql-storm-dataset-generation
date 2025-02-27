
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        STRING_AGG(DISTINCT t.TagName, ',') AS TagsArray
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    OUTER APPLY (
        SELECT value AS TagName 
        FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')
    ) AS t
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId, u.DisplayName
    ORDER BY 
        p.CreationDate DESC
    OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
),
VotesSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
TopContributors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    vs.UpVotes,
    vs.DownVotes,
    vs.TotalVotes,
    rp.TagsArray,
    tc.UserId AS TopContributorId,
    tc.DisplayName AS TopContributorName,
    tc.PostsCount,
    tc.TotalScore
FROM 
    RecentPosts rp
LEFT JOIN 
    VotesSummary vs ON rp.PostId = vs.PostId
LEFT JOIN 
    TopContributors tc ON rp.OwnerUserId = tc.UserId
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
