WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Considering only close and reopen history
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount, -- Upvotes
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount -- Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
    GROUP BY 
        p.Id
), 
EnhancedPostDetails AS (
    SELECT 
        pd.*,
        CASE 
            WHEN rph.rn = 1 THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus,
        CASE 
            WHEN pd.Score > 0 THEN 'Positive'
            ELSE 'Negative'
        END AS ScoreType
    FROM 
        PostDetails pd
    LEFT JOIN 
        RecursivePostHistory rph ON pd.PostId = rph.PostId
)

SELECT 
    epd.PostId,
    epd.Title,
    epd.Score,
    epd.ViewCount,
    epd.CommentCount,
    epd.UpVoteCount,
    epd.DownVoteCount,
    epd.PostStatus,
    epd.ScoreType,
    ARRAY_TO_STRING(ARRAY(SELECT DISTINCT t.TagName 
                          FROM Tags t 
                          JOIN LATERAL unnest(string_to_array(p.Tags, '<>')) AS tag ON t.TagName = tag) , ', ') AS TagList
FROM 
    EnhancedPostDetails epd
ORDER BY 
    epd.Score DESC, 
    epd.ViewCount DESC;
