WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AnswerCount,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.Score,
        a.ViewCount,
        a.OwnerUserId,
        a.AnswerCount,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE r ON a.ParentId = r.PostId
    WHERE 
        a.PostTypeId = 2 -- Answers only
),
PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpvoteCount, -- Count of Upvotes
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownvoteCount -- Count of Downvotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ',') AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.Level,
    pvs.UpvoteCount,
    pvs.DownvoteCount,
    ub.BadgeCount,
    ub.Badges
FROM 
    RecursivePostCTE r
LEFT JOIN 
    PostVoteSummary pvs ON r.PostId = pvs.PostId
LEFT JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    r.Score > 0 -- Only include posts with a positive score
    AND r.Level <= 3 -- Limit to direct answers and 2 levels of replies
ORDER BY 
    r.CreationDate DESC, 
    r.Score DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY; -- Pagination
