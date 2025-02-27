WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName as Author,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
SelectedPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Author,
        rp.CommentCount,
        rp.UpVotes - rp.DownVotes AS NetVotes,
        rp.VoteRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.VoteRank <= 10
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(TRIM(UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>'))) ) , ', ') AS Tags
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        p.Id
)
SELECT 
    sp.PostId,
    sp.Title,
    sp.CreationDate,
    sp.Author,
    sp.CommentCount,
    sp.NetVotes,
    pt.Tags
FROM 
    SelectedPosts sp
LEFT JOIN 
    PostTags pt ON sp.PostId = pt.PostId
ORDER BY 
    sp.NetVotes DESC, sp.CreationDate DESC;
