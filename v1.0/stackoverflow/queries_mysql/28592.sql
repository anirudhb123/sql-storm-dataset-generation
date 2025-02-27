
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.LastActivityDate, 
        p.OwnerUserId, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.*,
        GROUP_CONCAT(SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '<>', n.n), '<>', -1) ORDER BY n.n SEPARATOR ', ') AS FormattedTags
    FROM 
        RankedPosts rp
    JOIN 
        (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) n ON CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '<>', '')) >= n.n - 1
    WHERE 
        rp.PostRank <= 5 
    GROUP BY 
        rp.PostID, rp.Title, rp.Body, rp.Tags, rp.CreationDate, rp.LastActivityDate, rp.OwnerUserId, rp.OwnerDisplayName, rp.AnswerCount, rp.UpVotes, rp.DownVotes
),
UserStats AS (
    SELECT 
        u.Id AS UserID,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    fp.OwnerDisplayName,
    fp.Title,
    fp.FormattedTags,
    fp.CreationDate,
    fp.LastActivityDate,
    us.Reputation,
    us.BadgeCount,
    us.TotalViews,
    fp.AnswerCount,
    fp.UpVotes,
    fp.DownVotes
FROM 
    FilteredPosts fp
JOIN 
    UserStats us ON fp.OwnerUserId = us.UserID
ORDER BY 
    fp.CreationDate DESC;
