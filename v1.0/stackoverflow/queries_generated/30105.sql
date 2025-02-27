WITH RecursivePostHierarchy AS (
    SELECT
        p.Id,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        p.CreationDate,
        1 AS Depth
    FROM
        Posts p
    WHERE
        p.ParentId IS NULL

    UNION ALL

    SELECT
        p.Id,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        p.CreationDate,
        ph.Depth + 1
    FROM
        Posts p
    INNER JOIN RecursivePostHierarchy ph ON p.ParentId = ph.Id
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM
        Badges b
    GROUP BY
        b.UserId
),
PostStats AS (
    SELECT
        p.Id,
        p.Title,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(phs.BadgeCount, 0) AS UserBadgeCount
    FROM
        Posts p
    LEFT JOIN (
        SELECT
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM
            Votes
        GROUP BY
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM
            Comments
        GROUP BY
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN UserBadges phs ON p.OwnerUserId = phs.UserId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalStats AS (
    SELECT 
        ps.Id,
        ps.Title,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.CommentCount,
        phs.HistoryCount,
        phs.LastEdited,
        u.Reputation AS UserReputation,
        u.DisplayName AS UserDisplayName
    FROM 
        PostStats ps
    JOIN Posts p ON ps.Id = p.Id
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostHistorySummary phs ON ps.Id = phs.PostId
)

SELECT 
    RPH.Depth,
    FS.Id,
    FS.Title,
    FS.UpVoteCount,
    FS.DownVoteCount,
    FS.CommentCount,
    FS.HistoryCount,
    FS.LastEdited,
    FS.UserReputation,
    FS.UserDisplayName
FROM 
    RecursivePostHierarchy RPH
JOIN FinalStats FS ON RPH.Id = FS.Id
ORDER BY 
    RPH.Depth, FS.UpVoteCount DESC;
