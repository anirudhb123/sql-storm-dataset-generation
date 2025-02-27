WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- Count only UpVotes
    WHERE 
        p.PostTypeId IN (1, 2)  -- Only Questions and Answers
    GROUP BY 
        p.Id, u.DisplayName
), RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryCreationDate,
        ph.Comment AS HistoryComment,
        p.Title AS PostTitle
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
        AND ph.PostHistoryTypeId IN (10, 11, 12)  -- Close, Reopen, and Deleted actions
), PostWithHistory AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerName,
        rp.Rank,
        rp.CommentCount,
        rp.VoteCount,
        COALESCE(rph.HistoryCreationDate, 'No Recent History') AS RecentHistory,
        COALESCE(rph.HistoryComment, 'N/A') AS RecentHistoryComment
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentPostHistory rph ON rp.PostId = rph.PostId
)
SELECT 
    p.*,
    CASE 
        WHEN p.Score > 0 THEN 'Positive'
        WHEN p.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreMood,
    CASE 
        WHEN p.ViewCount > 100 THEN 'High Popularity'
        WHEN p.ViewCount > 50 THEN 'Moderate Popularity'
        ELSE 'Low Popularity'
    END AS ViewPopularity,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    PostWithHistory p
LEFT JOIN 
    LATERAL (
        SELECT 
            t.Id, t.TagName
        FROM 
            UNNEST(string_to_array(substring(p.Title, 2, length(p.Title)-2), '>')) AS t(TagName)
    ) AS t ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = t.TagName
WHERE 
    p.Rank <= 3  -- Selecting top 3 most recent posts per user
GROUP BY 
    p.PostId, p.CreationDate, p.OwnerName
ORDER BY 
    p.CreationDate DESC;
