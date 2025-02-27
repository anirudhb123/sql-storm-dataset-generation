WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(co.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments co ON co.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (2, 3)  -- UpVotes and DownVotes
    LEFT JOIN 
        LATERAL unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON true
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.Body
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CommentCount,
        rp.VoteCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5  -- Top 5 posts per user
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    tp.Title,
    tp.CommentCount,
    tp.VoteCount,
    tp.Tags
FROM 
    Users u
JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId
ORDER BY 
    u.Reputation DESC, tp.VoteCount DESC;  -- Order by user reputation and post vote count
