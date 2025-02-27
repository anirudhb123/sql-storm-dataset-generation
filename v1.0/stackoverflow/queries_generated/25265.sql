WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))::int[])
    WHERE 
        p.PostTypeId = 1 -- Focus on Questions
    GROUP BY 
        p.Id
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags,
        rp.CommentCount,
        RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS PostRank
    FROM 
        RankedPosts rp
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesGiven,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesGiven
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.ViewCount,
    trp.Score,
    trp.Tags,
    trp.CommentCount,
    ue.DisplayName AS PostOwner,
    ue.PostsCreated,
    ue.UpVotesGiven,
    ue.DownVotesGiven
FROM 
    TopRankedPosts trp
JOIN 
    UserEngagement ue ON trp.PostId IN (SELECT AnswerId FROM Posts WHERE AcceptedAnswerId = trp.PostId)
WHERE 
    trp.PostRank <= 10 -- Get top 10 posts
ORDER BY 
    trp.Score DESC;

This query benchmarks string processing by performing a series of common operations such as aggregation and ranking along with string manipulation, specifically in the context of posts and their respective tags, comments, and user engagement metrics. It ensures a comprehensive look at the top questions in the Stack Overflow schema, highlighting their details alongside the creator's interaction with the platform.
