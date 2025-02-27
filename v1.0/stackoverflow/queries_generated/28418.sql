WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        p.Body,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int)
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
), FilteredPosts AS (
    SELECT 
        rp.*,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        RankedPosts rp
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.AnswerCount,
    fp.CreationDate,
    fp.Tags,
    fp.OwnerDisplayName,
    fp.OwnerReputation,
    fp.UpVotes,
    fp.DownVotes,
    CASE 
        WHEN fp.Rank <= 3 THEN 'Top Post' 
        WHEN fp.ViewCount > 1000 THEN 'Popular Post'
        ELSE 'Regular Post' 
    END AS PostCategory
FROM 
    FilteredPosts fp
WHERE 
    fp.Rank <= 3 OR fp.ViewCount > 1000
ORDER BY 
    fp.CreationDate DESC;
