WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Filter for questions only
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),
PostTags AS (
    SELECT 
        pt.PostId,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        PostsTags pt 
    JOIN 
        Tags t ON pt.TagId = t.Id
    GROUP BY 
        pt.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeList
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    r.PostId,
    r.Title,
    r.Body,
    r.OwnerDisplayName,
    r.CommentCount,
    r.Upvotes,
    r.Downvotes,
    r.CreationDate,
    pt.TagsList,
    ub.BadgeList
FROM 
    RankedPosts r
LEFT JOIN 
    PostTags pt ON r.PostId = pt.PostId
LEFT JOIN 
    UserBadges ub ON r.OwnerDisplayName = ub.UserId
WHERE 
    r.rn = 1  -- Consider only the most recent post for each Id
ORDER BY 
    r.Upvotes DESC, r.CommentCount DESC
LIMIT 100;  -- Limit results for benchmarking
