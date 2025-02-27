WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 -- Only Questions
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId AND b.Class = 1 -- Only Gold badges
    GROUP BY
        u.Id
),
PostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COALESCE(ph.UserDisplayName, 'No activity') AS LastEditor,
        MAX(ph.CreationDate) AS LastEditDate
    FROM
        Posts p
    LEFT JOIN
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Edits
    GROUP BY
        p.Id, p.Title, ph.UserDisplayName
),
AggregatedActivity AS (
    SELECT
        p.PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.PostTypeId = 1 -- Only Questions
    GROUP BY
        p.PostId, p.Title
),
PostDetails AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        ub.BadgeCount,
        ub.BadgeNames,
        pa.LastEditor,
        pa.LastEditDate,
        ag.CommentCount,
        ag.LastCommentDate,
        CASE
            WHEN rp.Score IS NULL THEN 'No score'
            WHEN rp.Score > 100 THEN 'Hot Question'
            ELSE 'Regular Question'
        END AS QuestionStatus,
        CASE 
            WHEN rp.AcceptedAnswerId IS NOT NULL THEN (SELECT Title FROM Posts WHERE Id = rp.AcceptedAnswerId)
            ELSE 'No accepted answer'
        END AS AcceptedAnswer
    FROM
        RankedPosts rp
    JOIN
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN
        PostActivity pa ON rp.PostId = pa.PostId
    LEFT JOIN
        AggregatedActivity ag ON rp.PostId = ag.PostId
    WHERE
        rp.Rank = 1 -- Most recent post per user
)
SELECT
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.CreationDate,
    pd.BadgeCount,
    pd.BadgeNames,
    pd.LastEditor,
    pd.LastEditDate,
    pd.QuestionStatus,
    pd.AcceptedAnswer,
    COALESCE(pd.CommentCount, 0) AS TotalComments,
    COALESCE(pd.LastCommentDate, 'No comments yet') AS LastCommentDate,
    CASE
        WHEN pd.CreationDate < NOW() - INTERVAL '1 year' THEN 'Legacy post'
        ELSE 'Recent post'
    END AS PostAgeCategory
FROM
    PostDetails pd
WHERE
    pd.Score > 0 -- Only posts with a positive score
ORDER BY
    pd.ViewCount DESC, pd.CreationDate DESC
LIMIT 50;
