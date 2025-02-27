WITH RecursivePostHistory AS (
    SELECT
        ph.Id,
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        ph.PostHistoryTypeId,
        ph.Text,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM
        PostHistory ph
),
AggregatedPostData AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        AVG(u.Reputation) AS AvgReputation,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN RecursivePostHistory rph ON p.Id = rph.PostId AND rph.rn = 1
    GROUP BY 
        p.Id, p.Title
),
ClosedPosts AS (
    SELECT
        p.Id AS PostId,
        MAX(ph.CreationDate) AS ClosedDate
    FROM
        Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE
        ph.PostHistoryTypeId = 10
    GROUP BY
        p.Id
)
SELECT 
    apd.PostId,
    apd.Title,
    apd.UpVotes,
    apd.DownVotes,
    apd.CommentCount,
    apd.AvgReputation,
    apd.LastEditDate,
    apd.Tags,
    COALESCE(cp.ClosedDate, 'Not Closed') AS Status,
    CASE 
        WHEN cp.ClosedDate IS NOT NULL AND apd.LastEditDate < cp.ClosedDate THEN 'Closed After Edit'
        ELSE 'Active or Not Edited After Closure'
    END AS EditStatus,
    COUNT(DISTINCT ph.PostId) FILTER (WHERE ph.PostHistoryTypeId = 10) OVER (PARTITION BY apd.PostId) AS CloseVoteCount,
    COUNT(DISTINCT ph.PostId) FILTER (WHERE ph.PostHistoryTypeId IN (12, 13)) OVER () AS TotalDeleteUndeleteEvents
FROM 
    AggregatedPostData apd
LEFT JOIN ClosedPosts cp ON apd.PostId = cp.PostId
LEFT JOIN PostHistory ph ON apd.PostId = ph.PostId
WHERE 
    (apd.UpVotes - apd.DownVotes) > 0 
    OR apd.CommentCount > 5
ORDER BY 
    apd.UpVotes DESC, apd.CommentCount DESC;

