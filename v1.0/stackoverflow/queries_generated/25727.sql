WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_AGG(t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id
),
TopRankedPosts AS (
    SELECT 
        rp.*,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 10 -- Get top 10 questions by score and view count
),
PostWithBadges AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.CreationDate,
        trp.ViewCount,
        trp.Score,
        trp.Tags,
        trp.CommentCount,
        trp.UpVotes,
        trp.DownVotes,
        ARRAY_AGG(b.Name) AS Badges
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        Badges b ON b.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = trp.PostId)
    GROUP BY 
        trp.PostId, trp.Title, trp.CreationDate, trp.ViewCount, trp.Score, trp.Tags, trp.CommentCount, trp.UpVotes, trp.DownVotes
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.CreationDate,
    pwb.ViewCount,
    pwb.Score,
    pwb.Tags,
    pwb.CommentCount,
    pwb.UpVotes,
    pwb.DownVotes,
    COALESCE(pwb.Badges, ARRAY[]::varchar[]) AS UserBadges
FROM 
    PostWithBadges pwb
ORDER BY 
    pwb.Score DESC, pwb.ViewCount DESC;
