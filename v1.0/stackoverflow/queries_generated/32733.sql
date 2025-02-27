WITH RecursiveUserTags AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        t.TagName,
        ROW_NUMBER() OVER(PARTITION BY u.Id ORDER BY COUNT(p.Id) DESC) AS TagRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        LATERAL string_to_array(p.Tags, ',') AS t(TagName) ON true
    GROUP BY 
        u.Id, u.DisplayName, t.TagName
), RecentVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        v.PostId, v.VoteTypeId
), UserBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId, b.Name
), PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        p.Id, p.Title, p.CreationDate
), TagAggregates AS (
    SELECT 
        tag.UserId,
        tag.TagName,
        SUM(CASE WHEN tag.TagRank <= 3 THEN 1 ELSE 0 END) AS TopTagCount
    FROM 
        RecursiveUserTags tag
    WHERE 
        tag.TagRank IS NOT NULL
    GROUP BY 
        tag.UserId, tag.TagName
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(b.BadgeCount, 0) AS TotalBadges,
    COUNT(DISTINCT ps.PostId) AS TotalPosts,
    SUM(ps.CommentCount) AS TotalComments,
    SUM(ps.UpVotes) AS TotalUpVotes,
    SUM(ps.DownVotes) AS TotalDownVotes,
    SUM(ta.TopTagCount) AS TotalTopTags
FROM 
    Users u
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    PostStats ps ON u.Id = ps.PostId
LEFT JOIN 
    TagAggregates ta ON u.Id = ta.UserId
GROUP BY 
    u.Id, u.DisplayName, b.BadgeCount
HAVING 
    SUM(ps.UpVotes) - SUM(ps.DownVotes) > 10
ORDER BY 
    TotalPosts DESC,
    TotalBadges DESC;
