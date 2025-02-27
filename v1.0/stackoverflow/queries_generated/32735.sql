WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1  -- Considering only Questions
        AND p.CreationDate >= DATEADD(year, -1, GETDATE())  -- Posts from the last year
),
PostComments AS (
    SELECT
        pc.PostId,
        COUNT(pc.Id) AS CommentCount
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1  -- Considering only Gold badges
    GROUP BY 
        b.UserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.ViewCount,
        pc.CommentCount,
        pv.UpVotes,
        pv.DownVotes,
        ub.BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.OwnerPostRank = 1 -- Only the highest scored question for each user
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.ViewCount,
    COALESCE(fp.CommentCount, 0) AS CommentCount,
    COALESCE(fp.UpVotes, 0) AS UpVotes,
    COALESCE(fp.DownVotes, 0) AS DownVotes,
    COALESCE(fp.BadgeCount, 0) AS BadgeCount,
    DENSE_RANK() OVER (ORDER BY fp.ViewCount DESC) AS ViewRank
FROM 
    FilteredPosts fp
WHERE 
    fp.ViewCount > 100  -- Only include posts with more than 100 views
ORDER BY 
    fp.ViewCount DESC, 
    fp.CreationDate DESC;
