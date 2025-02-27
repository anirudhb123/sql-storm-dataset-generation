WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 -- Question
        AND p.Score > 0 -- Only questions with a score > 0
), 
AggregatedUserVotes AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownvoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
), 
PostActivities AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        MIN(ph.CreationDate) AS FirstActivity,
        MAX(ph.CreationDate) AS LastActivity,
        COUNT(*) AS ActivityCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Close, Reopen, Deleted
    GROUP BY
        ph.PostId,
        ph.PostHistoryTypeId
)

SELECT 
    up.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    COALESCE(vv.UpvoteCount, 0) AS UpvoteCount,
    COALESCE(vv.DownvoteCount, 0) AS DownvoteCount,
    json_agg(DISTINCT t.TagName) AS Tags,
    pa.ActivityCount AS TotalActivities,
    pa.FirstActivity,
    pa.LastActivity
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    AggregatedUserVotes vv ON up.Id = vv.UserId
LEFT JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    PostActivities pa ON rp.PostId = pa.PostId
LEFT JOIN 
    LATERAL string_to_array(rp.Tags, ',') AS TagName ON true 
LEFT JOIN 
    Tags t ON t.TagName = TRIM(BOTH ' ' FROM TagName) -- Match with existing tags
WHERE 
    rp.RowNum = 1 -- Select the most recent post for each user
GROUP BY 
    up.DisplayName, 
    u.Reputation, 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    vv.UpvoteCount,
    vv.DownvoteCount,
    pa.ActivityCount,
    pa.FirstActivity,
    pa.LastActivity
ORDER BY 
    rp.ViewCount DESC
LIMIT 100;
