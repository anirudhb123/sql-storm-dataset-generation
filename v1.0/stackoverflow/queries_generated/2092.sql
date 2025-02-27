WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerUserId,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        U.Reputation,
        COALESCE(b.Name, 'No Badge') AS BadgeName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users U ON rp.OwnerUserId = U.Id
    LEFT JOIN 
        Badges b ON U.Id = b.UserId AND b.Class = 1
    WHERE 
        rp.rn = 1
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    CASE 
        WHEN tp.UpVoteCount > tp.DownVoteCount THEN 'Positive'
        WHEN tp.UpVoteCount < tp.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    CASE 
        WHEN tp.Reputation IS NULL THEN 'Unknown Reputation'
        ELSE tp.Reputation::text
    END AS Reputation,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Posts p2 
     JOIN Tags t ON t.Id = ANY(string_to_array(p2.Tags, ', ')::int[])
     WHERE p2.Id = tp.Id) AS TagsUsed
FROM 
    TopPosts tp
ORDER BY 
    tp.CommentCount DESC, 
    tp.UpVoteCount - tp.DownVoteCount DESC
LIMIT 10;
