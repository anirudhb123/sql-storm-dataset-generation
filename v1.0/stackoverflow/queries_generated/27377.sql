-- Benchmarking string processing in the Stack Overflow schema
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames  -- Aggregate badge names into a single string
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostTags AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerDisplayName,
        p.Title,
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag  -- Process and split tags
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
), 
PostStatistics AS (
    SELECT 
        pt.PostId,
        pt.OwnerDisplayName,
        pt.Title,
        STRING_AGG(pt.Tag, ', ') AS AllTags,  -- Combine all tags for a post
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(b.Reputation), 0) AS TotalUserReputation  -- Calculate total reputation of users who commented or voted
    FROM 
        PostTags pt
    LEFT JOIN 
        Comments c ON pt.PostId = c.PostId
    LEFT JOIN 
        Votes v ON pt.PostId = v.PostId
    LEFT JOIN 
        Users b ON c.UserId = b.Id OR v.UserId = b.Id
    GROUP BY 
        pt.PostId, pt.OwnerDisplayName, pt.Title
)
SELECT 
    ub.UserId,
    ub.DisplayName,
    ub.BadgeCount,
    ub.BadgeNames,
    ps.Title,
    ps.AllTags,
    ps.CommentCount,
    ps.VoteCount,
    ps.TotalUserReputation
FROM 
    UserBadges ub
JOIN 
    PostStatistics ps ON ub.UserId = ps.OwnerDisplayName
ORDER BY 
    ps.VoteCount DESC, 
    ub.BadgeCount DESC;
