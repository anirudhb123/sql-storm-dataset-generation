WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        ARRAY_AGG(t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        LATERAL UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '> <'))::varchar[]) AS t(TagName) ON true
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.Reputation
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerReputation,
        rp.Rank,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
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
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerReputation,
    tp.CreationDate,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    tp.Tags
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteStats pvs ON tp.PostId = pvs.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
