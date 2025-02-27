WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    JOIN Tags t ON t.WikiPostId = p.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, p.CreationDate, p.PostTypeId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason,
        ph.UserDisplayName AS UserWhoClosed,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS close_rn
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId IN (2, 8) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId IN (3, 12) THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT ph.PostId) AS PostsEdited
    FROM Users u
    LEFT JOIN Votes v ON v.UserId = u.Id
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id OR p.LastEditorUserId = u.Id
    LEFT JOIN PostHistory ph ON ph.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.UpVotes - ua.DownVotes AS NetVotes,
        DENSE_RANK() OVER (ORDER BY ua.UpVotes DESC) AS UserRank
    FROM UserActivity ua
    WHERE ua.NetVotes > 0
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CreationDate,
    rp.Tags,
    cp.ClosedDate,
    cp.CloseReason,
    cp.UserWhoClosed,
    tu.DisplayName AS TopUser,
    tu.UserRank
FROM RankedPosts rp
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId AND cp.close_rn = 1
LEFT JOIN TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE rp.rn <= 10
AND (rp.Tags ILIKE '%SQL%' OR rp.Tags ILIKE '%performance%')
ORDER BY rp.Score DESC, rp.CreationDate DESC;
