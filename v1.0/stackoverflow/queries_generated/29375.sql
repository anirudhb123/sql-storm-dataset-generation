WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.*,
        COUNT(c.Id) AS CommentCount,
        (SELECT COUNT(DISTINCT t.TagName) FROM Tags t WHERE t.Id IN (SELECT UNNEST(string_to_array(rp.Tags, '<>'))::int)) AS UniqueTagCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    WHERE 
        rp.Rank <= 10 -- Top 10 ranked questions
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.Tags, rp.CreationDate, rp.ViewCount, rp.UpVotes, rp.DownVotes, rp.Rank
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    tp.UniqueTagCount,
    CASE 
        WHEN tp.UpVotes > tp.DownVotes THEN 'Positive'
        WHEN tp.UpVotes < tp.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    TopPosts tp
ORDER BY 
    tp.Rank;
