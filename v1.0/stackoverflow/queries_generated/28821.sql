WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Last year
),
TopPosts AS (
    SELECT 
        rp.TagName,
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1  -- Get latest post for each tag
),
PostVoteCounts AS (
    SELECT 
        p.Id,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    tp.TagName,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score + COALESCE(pvc.UpVotes, 0) AS TotalScore,
    tp.ViewCount,
    pvc.UpVotes,
    pvc.DownVotes
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteCounts pvc ON tp.PostId = pvc.Id
ORDER BY 
    TotalScore DESC, 
    tp.CreationDate DESC
LIMIT 10;  -- Top 10 posts
