WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount,
        COALESCE(u.DisplayName, 'Community') AS AuthorDisplayName,
        u.Reputation AS AuthorReputation,
        p.CreationDate,
        p.LastActivityDate
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1  -- Only questions
), 
RecentHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
    WHERE ph.CreationDate >= NOW() - INTERVAL '30 days'  -- History from the last 30 days
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CloseDate,
        ph.Comment AS CloseReason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10  -- Closed posts
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.TagCount,
    tp.AuthorDisplayName,
    tp.AuthorReputation,
    tp.CreationDate,
    tp.LastActivityDate,
    rp.UserDisplayName AS LastEditor,
    rp.CreationDate AS LastEditDate,
    cp.CloseDate,
    cp.CloseReason
FROM TaggedPosts tp
LEFT JOIN RecentHistory rp ON tp.PostId = rp.PostId AND rp.rn = 1
LEFT JOIN ClosedPosts cp ON tp.PostId = cp.PostId
ORDER BY tp.CreationDate DESC
LIMIT 100;

