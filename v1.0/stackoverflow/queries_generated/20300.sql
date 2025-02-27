WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotesCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotesCount,
        COALESCE(MAX(b.Class), 0) AS MaxBadgeLevel
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    GROUP BY p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.AcceptedAnswerId
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.UpVotesCount,
        rp.DownVotesCount,
        rp.MaxBadgeLevel,
        CASE 
            WHEN rp.UpVotesCount - rp.DownVotesCount > 10 AND rp.MaxBadgeLevel >= 2 THEN 'High Engagement'
            WHEN rp.UpVotesCount > 0 AND rp.MaxBadgeLevel = 0 THEN 'New Contributor'
            ELSE 'Notable'
        END AS EngagementLevel,
        string_agg(DISTINCT t.TagName, ', ') AS Tags
    FROM RankedPosts rp
    LEFT JOIN Posts p ON rp.PostId = p.Id
    LEFT JOIN Tags t ON t.Id = ANY(string_to_array(p.Tags, '><')::int[])
    WHERE rp.OwnerRank <= 5
    GROUP BY rp.PostId, rp.Title, rp.CreationDate, rp.UpVotesCount, rp.DownVotesCount, rp.MaxBadgeLevel
),

CloseReasons AS (
    SELECT 
        ph.PostId,
        array_agg(DISTINCT crt.Name) AS CloseReasonNames
    FROM PostHistory ph
    JOIN CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE ph.PostHistoryTypeId IN (10, 11)
    GROUP BY ph.PostId
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.UpVotesCount,
    fp.DownVotesCount,
    fp.EngagementLevel,
    COALESCE(cr.CloseReasonNames, '{}') AS ReasonsForClosure
FROM FilteredPosts fp
LEFT JOIN CloseReasons cr ON fp.PostId = cr.PostId
WHERE 
    (fp.EngagementLevel = 'High Engagement' AND fp.UpVotesCount > 50) OR
    (fp.EngagementLevel = 'New Contributor' AND fp.CreationDate >= NOW() - INTERVAL '1 month')
ORDER BY fp.CreationDate DESC
LIMIT 100;
