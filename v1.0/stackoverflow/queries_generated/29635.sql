WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ', ' ORDER BY t.TagName) AS Tags,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, '><')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score
), SortedPosts AS (
    SELECT 
        rp.*,
        RANK() OVER (ORDER BY rp.Score DESC, rp.CommentCount DESC, rp.CreationDate ASC) AS Rank
    FROM 
        RankedPosts rp
)

SELECT 
    sp.PostId,
    sp.Title,
    sp.Body,
    sp.CreationDate,
    sp.Score,
    sp.Tags,
    sp.CommentCount,
    sp.UpVotes,
    sp.DownVotes,
    sp.Rank,
    CASE 
        WHEN sp.Rank <= 5 THEN 'Top 5 Questions'
        WHEN sp.Score >= 50 THEN 'Popular Questions'
        ELSE 'Other Questions'
    END AS Classification
FROM 
    SortedPosts sp
WHERE 
    sp.CommentCount > 10 -- Filter for highly discussed questions
ORDER BY 
    sp.Rank, sp.Score DESC;
