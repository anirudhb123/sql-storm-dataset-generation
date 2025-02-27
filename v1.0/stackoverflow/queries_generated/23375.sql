WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(v.UpVotesCount, 0) AS UpVotesCount,
        COALESCE(v.DownVotesCount, 0) AS DownVotesCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankWithinType
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.UpVotesCount,
    rp.DownVotesCount,
    rp.CommentCount,
    CASE WHEN rp.RankWithinType = 1 THEN 'Latest' ELSE 'Older' END AS RecencyIndicator,
    (
        SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
        FROM Tags t 
        WHERE t.Id IN (
            SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><'))::int)
        )
    ) AS TagsList,
    (
        SELECT 
            COUNT(*) 
        FROM 
            PostHistory ph 
        WHERE 
            ph.PostId = rp.PostId 
            AND ph.PostHistoryTypeId IN (10, 11) 
            AND ph.UserId IS NOT NULL
    ) AS ChangeCount
FROM 
    RankedPosts rp
WHERE 
    rp.UpVotesCount - rp.DownVotesCount > 3
    AND EXISTS (
        SELECT 1 
        FROM Posts p2 
        WHERE p2.AcceptedAnswerId = rp.PostId
    )
ORDER BY 
    rp.CreationDate DESC
LIMIT 15;

-- Include posts with potential NULL vote counts where users have added comments, 
-- but exclude those without any votes, demonstrating NULL logic corner cases.
