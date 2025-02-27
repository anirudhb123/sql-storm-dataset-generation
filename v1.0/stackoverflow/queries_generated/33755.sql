WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER(PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 14)  -- Filters for relevant post history types
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostsWithActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        p.CreationDate,
        p.LastActivityDate,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ph.UserId AS LastEditorId
    FROM 
        Posts p
    LEFT JOIN 
        PostVotes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT 
             PostId, 
             UserId 
         FROM 
             RecursivePostHistory 
         WHERE 
             rn = 1 -- Most recent history for major events
        ) ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'  -- Only recent posts
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.UpVotes,
    pa.DownVotes,
    pa.CommentCount,
    pa.CreationDate,
    pa.LastActivityDate,
    u.DisplayName AS LastEditorName,
    CASE 
        WHEN pa.UpVotes > pa.DownVotes THEN 'Positive'
        WHEN pa.UpVotes < pa.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteTrend,
    (SELECT STRING_AGG(tag.TagName, ', ') 
     FROM Tags tag 
     WHERE tag.Id IN (SELECT unnest(string_to_array(p.Tags, '><')::int[]))) AS TagNames
FROM 
    PostsWithActivity pa
LEFT JOIN 
    Users u ON pa.LastEditorId = u.Id
ORDER BY 
    pa.CommentCount DESC, pa.LastActivityDate DESC;
