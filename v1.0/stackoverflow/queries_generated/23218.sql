WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(month, -12, GETDATE())
),
TopPosts AS (
    SELECT 
        r.*,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = r.PostId) AS CommentCount,
        (SELECT STRING_AGG(tag.TagName, ', ') 
         FROM Tags tag 
         WHERE tag.Id IN (SELECT unnest(string_to_array(p.Tags, '<>'))::int)) AS RelatedTags
    FROM 
        RankedPosts r
    WHERE 
        r.Rank <= 5
),
VoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.LastActivityDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.RelatedTags,
    COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN tp.Score IS NULL OR tp.Score = 0 THEN 'Neutral'
        WHEN tp.Score > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS ScoreSentiment,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Badges b WHERE b.UserId IN 
            (SELECT p.OwnerUserId 
             FROM Posts p WHERE p.Id = tp.PostId) AND b.Class = 1) 
        THEN 'Has Gold Badge' 
        ELSE 'No Gold Badge' 
    END AS OwnerBadgeStatus
FROM 
    TopPosts tp
LEFT JOIN 
    VoteSummary vs ON tp.PostId = vs.PostId
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC, tp.ViewCount DESC;
