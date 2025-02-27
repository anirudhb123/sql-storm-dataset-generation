WITH RecursivePostHierarchy AS (
    -- Base case: Select questions (PostTypeId = 1) and their accepted answers
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1

    UNION ALL

    -- Recursive case: Join with answers (PostTypeId = 2) based on ParentId
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        rp.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rp ON p.ParentId = rp.PostId
    WHERE p.PostTypeId = 2
),
PostVoteAggregates AS (
    -- Aggregate upvotes and downvotes per post
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),
UserBadges AS (
    -- Get user details along with the count of their badges
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
)

SELECT 
    rph.PostId,
    rph.Title,
    u.DisplayName AS OwnerDisplayName,
    u.BadgeCount,
    COALESCE(pva.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pva.DownVotes, 0) AS TotalDownVotes,
    rph.Level,
    COUNT(c.Id) AS CommentCount,
    P.HistoryComment AS LastPostEditComment,
    CASE 
        WHEN p.LastActivityDate >= NOW() - INTERVAL '30 days' THEN 'Active'
        ELSE 'Inactive'
    END AS PostStatus
FROM RecursivePostHierarchy rph
LEFT JOIN UserBadges u ON rph.OwnerUserId = u.UserId
LEFT JOIN PostVoteAggregates pva ON rph.PostId = pva.PostId
LEFT JOIN Comments c ON rph.PostId = c.PostId
LEFT JOIN (
    SELECT 
        PostId, 
        MAX(CreationDate) AS LastEditDate,
        STRING_AGG(Comment, ', ') AS HistoryComment
    FROM PostHistory 
    WHERE PostHistoryTypeId IN (4, 5) -- considering title or body edits
    GROUP BY PostId
) AS P ON rph.PostId = P.PostId
GROUP BY 
    rph.PostId, 
    rph.Title, 
    u.DisplayName, 
    u.BadgeCount, 
    pva.UpVotes, 
    pva.DownVotes,
    rph.Level,
    P.HistoryComment
ORDER BY 
    TotalUpVotes DESC, 
    rph.Level, 
    LastEditDate DESC;
