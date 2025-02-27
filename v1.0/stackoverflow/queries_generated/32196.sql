WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        Score,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL -- Base case: select top-level posts

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        p.Score,
        ph.Level + 1 -- Increase level for child posts
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.Id -- Recursive join to fetch hierarchy
),
TaggedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        TRIM(UNNEST(string_to_array(p.Tags, ','))) AS Tag
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),
VoteStatistics AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(vs.UpVotes, 0) - COALESCE(vs.DownVotes, 0) AS NetVotes,
        ph.Level,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT tp.Tag) AS UniqueTags
    FROM 
        Posts p
    LEFT JOIN 
        VoteStatistics vs ON p.Id = vs.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        RecursivePostHierarchy ph ON p.Id = ph.Id
    LEFT JOIN 
        TaggedPosts tp ON p.Id = tp.Id
    GROUP BY 
        p.Id, ph.Level, p.Title, vs.UpVotes, vs.DownVotes
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.NetVotes,
    ps.Level,
    ps.CommentCount,
    ps.UniqueTags,
    u.Reputation AS UserReputation,
    u.DisplayName AS UserDisplayName,
    ub.BadgeCount AS UserBadgeCount
FROM 
    PostSummary ps
JOIN 
    Users u ON ps.PostId = u.AccountId -- Assuming AccountId relates to post authors
LEFT JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
WHERE 
    ps.NetVotes > 0 -- Filter for popular posts
    AND ps.UniqueTags > 2 -- Filter for posts with more than 2 unique tags
ORDER BY 
    ps.NetVotes DESC, ps.CommentCount DESC; -- Order by NetVotes and then by CommentCount
