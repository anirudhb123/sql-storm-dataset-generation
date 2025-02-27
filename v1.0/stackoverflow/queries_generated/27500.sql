WITH PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.AnswerCount,
        p.CommentCount,
        ph.Comment AS PostEditComment,
        ph.CreationDate AS LastEditDate,
        COALESCE(CONCAT('https://stackoverflow.com/posts/', p.Id), '') AS PostUrl,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostType
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6, 10) -- Tracking Title, Body, Tags Edited, and Post Closed
    LEFT JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created within the last year
    GROUP BY
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, p.AnswerCount, p.CommentCount, ph.Comment, ph.CreationDate
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS UserPosts,
        COUNT(DISTINCT b.Id) AS UserBadges,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id, u.DisplayName
)
SELECT
    pd.PostId,
    pd.Title,
    pd.Tags,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.OwnerDisplayName,
    us.UserPosts,
    us.UserBadges,
    us.TotalBounty,
    us.TotalUpvotes,
    us.TotalDownvotes,
    pd.LastEditDate,
    pd.PostEditComment,
    pd.PostUrl,
    pd.PostType
FROM
    PostDetails pd
JOIN
    UserStats us ON pd.OwnerDisplayName = us.DisplayName
ORDER BY
    pd.ViewCount DESC, pd.Score DESC
LIMIT 50; -- Retrieve the top 50 posts based on view count and score
