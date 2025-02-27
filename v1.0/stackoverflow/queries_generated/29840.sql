WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS TotalUpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS TotalDownVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.TotalUpVotes,
        rp.TotalDownVotes,
        rp.TotalComments
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
    ORDER BY 
        rp.TotalUpVotes DESC 
    LIMIT 10
),
TagsProcessing AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    JOIN 
        LATERAL (SELECT UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS TagName) AS t ON TRUE
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.TotalUpVotes,
    tp.TotalDownVotes,
    tp.TotalComments,
    tp.Body,
    tp.TagsList
FROM 
    TopPosts tp
JOIN 
    TagsProcessing t ON tp.PostId = t.PostId
ORDER BY 
    tp.TotalUpVotes DESC;
