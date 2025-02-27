WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
), ActivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(ph.Comment, 'No comments') AS LastComment,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, MAX(CreationDate) AS LastCommentDate FROM Comments GROUP BY PostId) latest_comments 
        ON p.Id = latest_comments.PostId
    LEFT JOIN 
        PostHistory ph ON latest_comments.PostId = ph.PostId 
        AND latest_comments.LastCommentDate = ph.CreationDate 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '2 week'
), PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = p.TagId
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    ur.Upvotes,
    ur.Downvotes,
    pp.Title,
    pp.ViewCount,
    pp.AnswerCount,
    ph.CreationDate AS LastEdit,
    pb.BadgeCount,
    pb.BadgeNames,
    pt.TagName,
    pt.PostCount
FROM 
    Users u
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    ActivePosts pp ON pp.PostId = (
        SELECT PostId FROM Posts ORDER BY CreationDate LIMIT 1
    )
LEFT JOIN 
    UserBadges pb ON u.Id = pb.UserId
LEFT JOIN 
    PopularTags pt ON pt.PostCount > 5
WHERE 
    (ur.Upvotes - ur.Downvotes) > 0  -- Users with more Upvotes than Downvotes
    AND pp.ViewCount IS NOT NULL  -- Ensure there are views for the posts
ORDER BY 
    ur.Upvotes DESC, pp.ViewCount DESC; -- Order by user reputation and post views
